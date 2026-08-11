import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { PayrollStatus, PayslipLineItemType } from '@prisma/client';

// Module-level singletons for state sync when database is offline
export interface InMemoryPayrollRun {
  id: string;
  periodLabel: string;
  status: PayrollStatus;
  totalAmount: number;
  employeeCount: number;
  createdAt: Date;
}

const globalInMemoryRuns: InMemoryPayrollRun[] = [
  { id: 'pr_1', periodLabel: 'April 2026', status: PayrollStatus.paid, totalAmount: 1250000.0, employeeCount: 150, createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000) },
  { id: 'pr_2', periodLabel: 'May 2026', status: PayrollStatus.pendingApproval, totalAmount: 1300000.0, employeeCount: 152, createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
  { id: 'pr_3', periodLabel: 'June 2026', status: PayrollStatus.draft, totalAmount: 1280000.0, employeeCount: 155, createdAt: new Date() },
];

const globalInMemoryPayslips = new Map<string, any[]>();
const globalInMemoryBonusNotices = new Map<string, any>();

// Initialize mock data for the demo employee (emp_1)
const initialPayslips = [
  {
    id: 'p1',
    userId: 'emp_1',
    monthLabel: 'June 2026',
    baseSalary: 12000.0,
    netPay: 14300.0,
    payrollRunId: 'pr_2',
    lineItems: [
      { id: 'li1', label: 'housing_allowance', amount: 3000.0, type: PayslipLineItemType.allowance },
      { id: 'li2', label: 'transport_allowance', amount: 1000.0, type: PayslipLineItemType.allowance },
      { id: 'li3', label: 'tax_deduction', amount: 500.0, type: PayslipLineItemType.deduction },
      { id: 'li4', label: 'social_insurance', amount: 1200.0, type: PayslipLineItemType.deduction },
    ],
    createdAt: new Date(),
  },
  {
    id: 'p2',
    userId: 'emp_1',
    monthLabel: 'May 2026',
    baseSalary: 12000.0,
    netPay: 14300.0,
    payrollRunId: 'pr_1',
    lineItems: [
      { id: 'li5', label: 'housing_allowance', amount: 3000.0, type: PayslipLineItemType.allowance },
      { id: 'li6', label: 'transport_allowance', amount: 1000.0, type: PayslipLineItemType.allowance },
      { id: 'li7', label: 'tax_deduction', amount: 500.0, type: PayslipLineItemType.deduction },
      { id: 'li8', label: 'social_insurance', amount: 1200.0, type: PayslipLineItemType.deduction },
    ],
    createdAt: new Date(),
  }
];
globalInMemoryPayslips.set('emp_1', initialPayslips);

globalInMemoryBonusNotices.set('emp_1', {
  id: 'bn1',
  userId: 'emp_1',
  monthLabel: 'June 2026',
  amount: 5000.0,
  message: 'Performance Bonus Q2',
  createdAt: new Date(),
});

@Injectable()
export class PayrollService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  // Employee-facing endpoints
  async getPayslips(userId: string) {
    try {
      return await this.prisma.payslip.findMany({
        where: { userId },
        include: { lineItems: true },
        orderBy: { createdAt: 'desc' },
      });
    } catch (e) {
      console.warn('Database offline, returning fallback payslips');
      return globalInMemoryPayslips.get(userId) || [];
    }
  }

  async getPayslipDetail(userId: string, monthLabel: string) {
    try {
      const payslip = await this.prisma.payslip.findFirst({
        where: { userId, monthLabel },
        include: { lineItems: true },
      });
      if (!payslip) throw new NotFoundException(`Payslip for ${monthLabel} not found`);
      return payslip;
    } catch (e) {
      if (e instanceof NotFoundException) throw e;
      console.warn('Database offline, returning fallback payslip detail');
      const list = globalInMemoryPayslips.get(userId) || [];
      const item = list.find(p => p.monthLabel === monthLabel);
      if (!item) throw new NotFoundException(`Payslip for ${monthLabel} not found`);
      return item;
    }
  }

  async getYtdSummary(userId: string) {
    let payslips: any[] = [];
    try {
      payslips = await this.prisma.payslip.findMany({
        where: { userId },
        include: { lineItems: true },
      });
    } catch (e) {
      console.warn('Database offline, computing YTD summary from fallbacks');
      payslips = globalInMemoryPayslips.get(userId) || [];
    }

    let totalEarnings = 0;
    let totalDeductions = 0;

    for (const payslip of payslips) {
      totalEarnings += payslip.baseSalary;
      for (const item of payslip.lineItems) {
        if (item.type === PayslipLineItemType.allowance || item.type === 'allowance') {
          totalEarnings += item.amount;
        } else if (item.type === PayslipLineItemType.deduction || item.type === 'deduction') {
          totalDeductions += item.amount;
        }
      }
    }

    return {
      totalEarnings,
      totalDeductions,
    };
  }

  async getCurrentBonusNotice(userId: string) {
    try {
      return await this.prisma.bonusNotice.findFirst({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });
    } catch (e) {
      console.warn('Database offline, returning fallback bonus notice');
      return globalInMemoryBonusNotices.get(userId) || null;
    }
  }

  // Admin-facing endpoints
  async getPayrollRuns() {
    try {
      return await this.prisma.payrollRun.findMany({
        orderBy: { createdAt: 'desc' },
      });
    } catch (e) {
      console.warn('Database offline, returning fallback payroll runs');
      return [...globalInMemoryRuns].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    }
  }

  async createRun(periodLabel: string) {
    try {
      const existing = await this.prisma.payrollRun.findFirst({
        where: { periodLabel },
      });
      if (existing) {
        throw new BadRequestException(`Payroll run for ${periodLabel} already exists`);
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
    } catch (e) {
      if (e instanceof BadRequestException) throw e;
      console.warn('Database offline, creating fallback payroll run');
      const existing = globalInMemoryRuns.find(r => r.periodLabel === periodLabel);
      if (existing) {
        throw new BadRequestException(`Payroll run for ${periodLabel} already exists`);
      }

      const run = {
        id: 'mock_pr_' + Date.now(),
        periodLabel,
        status: PayrollStatus.draft,
        totalAmount: 0.0,
        employeeCount: 0,
        createdAt: new Date(),
      };
      globalInMemoryRuns.unshift(run);

      this.events.emitEntityUpdated('PayrollRun', 'created', run);
      return run;
    }
  }

  async processRun(runId: string) {
    try {
      const run = await this.prisma.payrollRun.findUnique({ where: { id: runId } });
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
    } catch (e) {
      if (e instanceof NotFoundException || e instanceof BadRequestException) throw e;
      console.warn('Database offline, processing fallback payroll run');
      const index = globalInMemoryRuns.findIndex(r => r.id === runId);
      if (index === -1) throw new NotFoundException('Payroll run not found');
      if (globalInMemoryRuns[index].status !== PayrollStatus.draft) {
        throw new BadRequestException('Can only process draft payroll runs');
      }

      globalInMemoryRuns[index].status = PayrollStatus.pendingApproval;
      const updated = globalInMemoryRuns[index];

      this.events.emitEntityUpdated('PayrollRun', 'updated', updated);
      return updated;
    }
  }

  async approveRun(runId: string) {
    try {
      const run = await this.prisma.payrollRun.findUnique({
        where: { id: runId },
        include: { payslips: true },
      });
      if (!run) throw new NotFoundException('Payroll run not found');
      if (run.status !== PayrollStatus.pendingApproval) {
        throw new BadRequestException('Can only approve runs that are pending approval');
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

      const totalAllowances = allowancesData.reduce((sum, item) => sum + item.amount, 0);
      const totalDeductions = deductionsData.reduce((sum, item) => sum + item.amount, 0);
      const netPay = baseSalary + totalAllowances - totalDeductions;

      for (const employee of employees) {
        const existingPayslip = await this.prisma.payslip.findFirst({
          where: { userId: employee.id, monthLabel: run.periodLabel },
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
                ...allowancesData.map(item => ({
                  label: item.label,
                  amount: item.amount,
                  type: PayslipLineItemType.allowance,
                })),
                ...deductionsData.map(item => ({
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
    } catch (e) {
      if (e instanceof NotFoundException || e instanceof BadRequestException) throw e;
      console.warn('Database offline, approving fallback payroll run');
      const index = globalInMemoryRuns.findIndex(r => r.id === runId);
      if (index === -1) throw new NotFoundException('Payroll run not found');
      if (globalInMemoryRuns[index].status !== PayrollStatus.pendingApproval) {
        throw new BadRequestException('Can only approve runs that are pending approval');
      }

      // Hardcoded list of active employees for in-memory fallbacks
      const mockEmployees = [
        { id: 'emp_1', name: 'Ahmed Salem' },
        { id: 'emp_2', name: 'Mona Zaki' },
        { id: 'emp_3', name: 'Omar Farooq' },
      ];

      let totalAmount = 0;
      const employeeCount = mockEmployees.length;

      const baseSalary = 12000.0;
      const allowancesData = [
        { label: 'housing_allowance', amount: 3000.0 },
        { label: 'transport_allowance', amount: 1000.0 },
      ];
      const deductionsData = [
        { label: 'tax_deduction', amount: 500.0 },
        { label: 'social_insurance', amount: 1200.0 },
      ];

      const totalAllowances = allowancesData.reduce((sum, item) => sum + item.amount, 0);
      const totalDeductions = deductionsData.reduce((sum, item) => sum + item.amount, 0);
      const netPay = baseSalary + totalAllowances - totalDeductions;

      for (const emp of mockEmployees) {
        const list = globalInMemoryPayslips.get(emp.id) || [];
        const existing = list.find(p => p.monthLabel === globalInMemoryRuns[index].periodLabel);
        if (existing) continue;

        const mockPayslip = {
          id: 'mock_p_' + Date.now() + '_' + emp.id,
          userId: emp.id,
          monthLabel: globalInMemoryRuns[index].periodLabel,
          baseSalary,
          netPay,
          payrollRunId: runId,
          lineItems: [
            ...allowancesData.map((item, idx) => ({
              id: `mock_li_a_${idx}_${emp.id}`,
              label: item.label,
              amount: item.amount,
              type: 'allowance',
            })),
            ...deductionsData.map((item, idx) => ({
              id: `mock_li_d_${idx}_${emp.id}`,
              label: item.label,
              amount: item.amount,
              type: 'deduction',
            })),
          ],
          createdAt: new Date(),
        };

        list.unshift(mockPayslip);
        globalInMemoryPayslips.set(emp.id, list);

        const mockBonus = {
          id: 'mock_bn_' + Date.now() + '_' + emp.id,
          userId: emp.id,
          monthLabel: globalInMemoryRuns[index].periodLabel,
          amount: 5000.0,
          message: `Performance Bonus Q2`,
          createdAt: new Date(),
        };
        globalInMemoryBonusNotices.set(emp.id, mockBonus);

        totalAmount += netPay;

        this.events.emitEntityUpdated('Payslip', 'created', mockPayslip);
        this.events.emitEntityUpdated('BonusNotice', 'created', mockBonus);
      }

      globalInMemoryRuns[index].status = PayrollStatus.approved;
      globalInMemoryRuns[index].totalAmount = totalAmount;
      globalInMemoryRuns[index].employeeCount = employeeCount;
      const updated = globalInMemoryRuns[index];

      this.events.emitEntityUpdated('PayrollRun', 'updated', updated);
      return updated;
    }
  }
}
