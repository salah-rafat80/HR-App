import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { PrismaModule } from './prisma/prisma.module';
import { EventsModule } from './events/events.module';
import { LeaveModule } from './leave/leave.module';
import { AttendanceModule } from './attendance/attendance.module';
import { CompanySettingsModule } from './company-settings/company-settings.module';
import { KpiModule } from './kpi/kpi.module';
import { AppraisalModule } from './appraisal/appraisal.module';
import { PayrollModule } from './payroll/payroll.module';
import { OvertimeModule } from './overtime/overtime.module';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 10,
      },
    ]),
    AuthModule,
    PrismaModule,
    EventsModule,
    LeaveModule,
    AttendanceModule,
    CompanySettingsModule,
    KpiModule,
    AppraisalModule,
    PayrollModule,
    OvertimeModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
