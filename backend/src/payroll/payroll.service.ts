import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { PayrollStatus, PayslipLineItemType } from '@prisma/client';

@Injectable()
export class PayrollService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  // Employee-facing endpoints
  async getPayslips(userId: string) {
    return this.prisma.payslip.findMany({
      where: { userId },
      include: { lineItems: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPayslipDetail(userId: string, monthLabel: string) {
    const payslip = await this.prisma.payslip.findFirst({
      where: { userId, monthLabel },
      include: { lineItems: true },
    });
    if (!payslip) {
      throw new NotFoundException(`Payslip for ${monthLabel} not found`);
    }
    return payslip;
  }

  async getYtdSummary(userId: string) {
    const payslips = await this.prisma.payslip.findMany({
      where: { userId },
      include: { lineItems: true },
    });

    let totalEarnings = 0;
    let totalDeductions = 0;

    for (const payslip of payslips) {
      totalEarnings += Number(payslip.baseSalary);
      for (const item of payslip.lineItems) {
        const amt = Number(item.amount);
        if (item.type === PayslipLineItemType.allowance) {
          totalEarnings += amt;
        } else if (item.type === PayslipLineItemType.deduction) {
          totalDeductions += amt;
        }
      }
    }

    return {
      totalEarnings,
      totalDeductions,
    };
  }

  async getCurrentBonusNotice(userId: string) {
    return this.prisma.bonusNotice.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // Admin-facing endpoints
  async getPayrollRuns() {
    return this.prisma.payrollRun.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async createRun(periodLabel: string) {
    const existing = await this.prisma.payrollRun.findFirst({
      where: { periodLabel },
    });
    if (existing) {
      throw new BadRequestException(
        `Payroll run for ${periodLabel} already exists`,
      );
    }

    const run = await this.prisma.payrollRun.create({
      data: {
        periodLabel,
        status: PayrollStatus.draft,
        totalAmount: 0,
        employeeCount: 0,
      },
    });

    this.events.emitEntityUpdated('PayrollRun', 'created', run);
    return run;
  }

  async processRun(runId: string) {
    const run = await this.prisma.payrollRun.findUnique({
      where: { id: runId },
    });
    if (!run) throw new NotFoundException('Payroll run not found');
    if (run.status !== PayrollStatus.draft) {
      throw new BadRequestException('Can only process draft payroll runs');
    }

    const updated = await this.prisma.payrollRun.update({
      where: { id: runId },
      data: { status: PayrollStatus.pendingApproval },
    });

    this.events.emitEntityUpdated('PayrollRun', 'updated', updated);
    return updated;
  }

  async approveRun(runId: string) {
    const run = await this.prisma.payrollRun.findUnique({
      where: { id: runId },
      include: { payslips: true },
    });
    if (!run) throw new NotFoundException('Payroll run not found');
    if (run.status !== PayrollStatus.pendingApproval) {
      throw new BadRequestException(
        'Can only approve runs that are pending approval',
      );
    }

    const employees = await this.prisma.user.findMany({
      where: { role: 'employee' },
    });

    let totalAmount = 0;
    const employeeCount = employees.length;

    const baseSalary = 12000.0;
    const allowancesData = [
      { label: 'housing_allowance', amount: 3000.0 },
      { label: 'transport_allowance', amount: 1000.0 },
    ];
    const deductionsData = [
      { label: 'tax_deduction', amount: 500.0 },
      { label: 'social_insurance', amount: 1200.0 },
    ];

    const totalAllowances = allowancesData.reduce(
      (sum, item) => sum + item.amount,
      0,
    );
    const totalDeductions = deductionsData.reduce(
      (sum, item) => sum + item.amount,
      0,
    );
    const netPay = baseSalary + totalAllowances - totalDeductions;

    for (const employee of employees) {
      const existingPayslip = await this.prisma.payslip.findFirst({
        where: { userId: employee.id, payrollRunId: run.id },
      });
      if (existingPayslip) continue;

      const payslip = await this.prisma.payslip.create({
        data: {
          userId: employee.id,
          monthLabel: run.periodLabel,
          baseSalary,
          netPay,
          payrollRunId: run.id,
          lineItems: {
            create: [
              ...allowancesData.map((item) => ({
                label: item.label,
                amount: item.amount,
                type: PayslipLineItemType.allowance,
              })),
              ...deductionsData.map((item) => ({
                label: item.label,
                amount: item.amount,
                type: PayslipLineItemType.deduction,
              })),
            ],
          },
        },
        include: { lineItems: true },
      });

      const bonusNotice = await this.prisma.bonusNotice.create({
        data: {
          userId: employee.id,
          monthLabel: run.periodLabel,
          amount: 5000.0,
          message: `Performance Bonus Q2`,
        },
      });

      totalAmount += netPay;

      this.events.emitEntityUpdated('Payslip', 'created', payslip);
      this.events.emitEntityUpdated('BonusNotice', 'created', bonusNotice);
    }

    const updated = await this.prisma.payrollRun.update({
      where: { id: runId },
      data: {
        status: PayrollStatus.approved,
        totalAmount: totalAmount > 0 ? totalAmount : run.totalAmount,
        employeeCount: employeeCount > 0 ? employeeCount : run.employeeCount,
      },
    });

    this.events.emitEntityUpdated('PayrollRun', 'updated', updated);
    return updated;
  }
}
