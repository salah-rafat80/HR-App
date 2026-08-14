import { Injectable } from '@nestjs/common';
import ExcelJS from 'exceljs';
import { AttendanceStatus, OvertimeSessionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { MonthlyReportQueryDto } from './dto/monthly-report-query.dto';

interface DailyRow {
  date: Date;
  dayType: 'working' | 'weekend' | 'holiday' | 'leave';
  attendanceStatus: string;
  clockIn: Date | null;
  clockOut: Date | null;
  normalMinutes: number;
  overtimeMinutes: number;
  note: string;
}

interface EmployeeSummary {
  employeeId: string;
  employeeCode: string;
  employeeName: string;
  department: string;
  workingDays: number;
  presentDays: number;
  absentDays: number;
  leaveDays: number;
  normalMinutes: number;
  overtimeMinutes: number;
  dailyRows: DailyRow[];
}

@Injectable()
export class HrReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async getMonthlyReport(query: MonthlyReportQueryDto) {
    const { monthStart, monthEnd } = this.monthBounds(query.month);
    const users = await this.prisma.user.findMany({
      where: {
        isActive: true,
        ...(query.department ? { department: query.department } : {}),
        ...(query.employeeId ? { id: query.employeeId } : {}),
      },
      select: { id: true, employeeCode: true, name: true, department: true },
      orderBy: [{ department: 'asc' }, { name: 'asc' }],
    });
    const userIds = users.map((user) => user.id);
    const [attendance, leaves, holidays, overtime] = await Promise.all([
      this.prisma.attendanceRecord.findMany({
        where: {
          userId: { in: userIds },
          date: { gte: monthStart, lt: monthEnd },
        },
      }),
      this.prisma.leaveRequest.findMany({
        where: {
          userId: { in: userIds },
          overallStatus: 'approved',
          startDate: { lt: monthEnd },
          endDate: { gte: monthStart },
        },
      }),
      this.prisma.companyHoliday.findMany({
        where: { isActive: true, date: { gte: monthStart, lt: monthEnd } },
      }),
      this.prisma.overtimeSession.findMany({
        where: {
          userId: { in: userIds },
          status: OvertimeSessionStatus.completed,
          startedAt: { gte: monthStart, lt: monthEnd },
        },
      }),
    ]);

    const attendanceByUserDate = new Map(
      attendance.map((record) => [
        `${record.userId}:${this.dateKey(record.date)}`,
        record,
      ]),
    );
    const holidayByDate = new Map(
      holidays.map((holiday) => [this.dateKey(holiday.date), holiday.name]),
    );
    const overtimeByUserDate = new Map<string, number>();
    for (const session of overtime) {
      const key = `${session.userId}:${this.dateKey(session.startedAt)}`;
      overtimeByUserDate.set(
        key,
        (overtimeByUserDate.get(key) ?? 0) + (session.actualMinutes ?? 0),
      );
    }

    const employees: EmployeeSummary[] = users.map((user) => {
      const dailyRows: DailyRow[] = [];
      let workingDays = 0;
      let presentDays = 0;
      let absentDays = 0;
      let leaveDays = 0;
      let normalMinutes = 0;
      let overtimeMinutes = 0;
      for (const date of this.monthDates(monthStart, monthEnd)) {
        const dateKey = this.dateKey(date);
        const record = attendanceByUserDate.get(`${user.id}:${dateKey}`);
        const holidayName = holidayByDate.get(dateKey);
        const onLeave = leaves.some(
          (leave) =>
            date >= this.startOfDay(leave.startDate) &&
            date <= this.startOfDay(leave.endDate),
        );
        const overtimeForDay =
          overtimeByUserDate.get(`${user.id}:${dateKey}`) ?? 0;
        const weekend = date.getUTCDay() === 5;
        let dayType: DailyRow['dayType'] = 'working';
        let status = record?.status ?? AttendanceStatus.none;
        let note = '';
        if (holidayName) {
          dayType = 'holiday';
          note = holidayName;
        } else if (weekend) {
          dayType = 'weekend';
          note = 'Friday weekend';
        } else if (onLeave) {
          dayType = 'leave';
          status = AttendanceStatus.onLeave;
          leaveDays++;
        } else {
          workingDays++;
          if (record?.clockInTime) presentDays++;
          else absentDays++;
        }
        const normalForDay = this.minutesBetween(
          record?.clockInTime ?? null,
          record?.clockOutTime ?? null,
        );
        normalMinutes += normalForDay;
        overtimeMinutes += overtimeForDay;
        dailyRows.push({
          date,
          dayType,
          attendanceStatus: status,
          clockIn: record?.clockInTime ?? null,
          clockOut: record?.clockOutTime ?? null,
          normalMinutes: normalForDay,
          overtimeMinutes: overtimeForDay,
          note,
        });
      }
      return {
        employeeId: user.id,
        employeeCode: user.employeeCode ?? '',
        employeeName: user.name,
        department: user.department ?? 'Unassigned',
        workingDays,
        presentDays,
        absentDays,
        leaveDays,
        normalMinutes,
        overtimeMinutes,
        dailyRows,
      };
    });

    return {
      month: query.month,
      filters: {
        department: query.department ?? null,
        employeeId: query.employeeId ?? null,
      },
      generatedAt: new Date(),
      totals: {
        employees: employees.length,
        workingDays: employees.reduce(
          (sum, employee) => sum + employee.workingDays,
          0,
        ),
        presentDays: employees.reduce(
          (sum, employee) => sum + employee.presentDays,
          0,
        ),
        absentDays: employees.reduce(
          (sum, employee) => sum + employee.absentDays,
          0,
        ),
        leaveDays: employees.reduce(
          (sum, employee) => sum + employee.leaveDays,
          0,
        ),
        normalMinutes: employees.reduce(
          (sum, employee) => sum + employee.normalMinutes,
          0,
        ),
        overtimeMinutes: employees.reduce(
          (sum, employee) => sum + employee.overtimeMinutes,
          0,
        ),
      },
      employees,
    };
  }

  async exportMonthlyReport(query: MonthlyReportQueryDto): Promise<Buffer> {
    const report = await this.getMonthlyReport(query);
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'HR App';
    workbook.created = new Date();

    const summary = workbook.addWorksheet('Summary');
    summary.addRows([
      ['HR Monthly Attendance & Overtime Report'],
      ['Month', report.month],
      ['Department filter', report.filters.department ?? 'All departments'],
      ['Employee filter', report.filters.employeeId ?? 'All employees'],
      ['Generated at', report.generatedAt],
      [],
      [
        'Employees',
        'Working days',
        'Present days',
        'Absent days',
        'Leave days',
        'Normal hours',
        'Overtime hours',
      ],
      [
        report.totals.employees,
        report.totals.workingDays,
        report.totals.presentDays,
        report.totals.absentDays,
        report.totals.leaveDays,
        report.totals.normalMinutes / 60,
        report.totals.overtimeMinutes / 60,
      ],
    ]);
    summary.getRow(1).font = { bold: true, size: 14 };
    summary.getRow(7).font = { bold: true };
    summary.columns = [
      { width: 24 },
      { width: 22 },
      { width: 18 },
      { width: 18 },
      { width: 16 },
      { width: 18 },
      { width: 18 },
    ];

    const employeeSheet = workbook.addWorksheet('Employee Summary');
    employeeSheet.columns = [
      { header: 'Employee Code', key: 'employeeCode', width: 18 },
      { header: 'Employee Name', key: 'employeeName', width: 28 },
      { header: 'Department', key: 'department', width: 22 },
      { header: 'Working Days', key: 'workingDays', width: 15 },
      { header: 'Present Days', key: 'presentDays', width: 15 },
      { header: 'Absent Days', key: 'absentDays', width: 15 },
      { header: 'Leave Days', key: 'leaveDays', width: 14 },
      { header: 'Normal Hours', key: 'normalHours', width: 16 },
      { header: 'Overtime Hours', key: 'overtimeHours', width: 18 },
    ];
    employeeSheet.getRow(1).font = { bold: true };
    report.employees.forEach((employee) =>
      employeeSheet.addRow({
        ...employee,
        normalHours: employee.normalMinutes / 60,
        overtimeHours: employee.overtimeMinutes / 60,
      }),
    );

    const dailySheet = workbook.addWorksheet('Daily Details');
    dailySheet.columns = [
      { header: 'Employee Code', key: 'employeeCode', width: 18 },
      { header: 'Employee Name', key: 'employeeName', width: 28 },
      { header: 'Department', key: 'department', width: 22 },
      { header: 'Date', key: 'date', width: 14 },
      { header: 'Day Type', key: 'dayType', width: 14 },
      { header: 'Attendance Status', key: 'attendanceStatus', width: 18 },
      { header: 'Clock In', key: 'clockIn', width: 20 },
      { header: 'Clock Out', key: 'clockOut', width: 20 },
      { header: 'Normal Hours', key: 'normalHours', width: 16 },
      { header: 'Overtime Hours', key: 'overtimeHours', width: 18 },
      { header: 'Note', key: 'note', width: 24 },
    ];
    dailySheet.getRow(1).font = { bold: true };
    report.employees.forEach((employee) =>
      employee.dailyRows.forEach((day) =>
        dailySheet.addRow({
          employeeCode: employee.employeeCode,
          employeeName: employee.employeeName,
          department: employee.department,
          date: day.date,
          dayType: day.dayType,
          attendanceStatus: day.attendanceStatus,
          clockIn: day.clockIn,
          clockOut: day.clockOut,
          normalHours: day.normalMinutes / 60,
          overtimeHours: day.overtimeMinutes / 60,
          note: day.note,
        }),
      ),
    );
    for (const sheet of [employeeSheet, dailySheet]) {
      sheet.views = [{ state: 'frozen', ySplit: 1 }];
      sheet.autoFilter = {
        from: 'A1',
        to: `${String.fromCharCode(64 + sheet.columnCount)}1`,
      };
      sheet.eachRow((row, index) => {
        if (index > 1 && index % 2 === 0)
          row.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFF5F7FA' },
          };
      });
    }
    return Buffer.from(await workbook.xlsx.writeBuffer());
  }

  private monthBounds(month: string) {
    const [year, monthNumber] = month.split('-').map(Number);
    const monthStart = new Date(Date.UTC(year, monthNumber - 1, 1));
    const monthEnd = new Date(Date.UTC(year, monthNumber, 1));
    return { monthStart, monthEnd };
  }

  private monthDates(start: Date, end: Date): Date[] {
    const dates: Date[] = [];
    for (
      let date = new Date(start);
      date < end;
      date.setUTCDate(date.getUTCDate() + 1)
    )
      dates.push(new Date(date));
    return dates;
  }

  private startOfDay(date: Date): Date {
    return new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );
  }

  private dateKey(date: Date): string {
    return this.startOfDay(date).toISOString().slice(0, 10);
  }

  private minutesBetween(start: Date | null, end: Date | null): number {
    if (!start || !end || end <= start) return 0;
    return Math.floor((end.getTime() - start.getTime()) / 60000);
  }
}
