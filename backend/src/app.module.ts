import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { PrismaModule } from './prisma/prisma.module';
import { EventsModule } from './events/events.module';
import { LeaveModule } from './leave/leave.module';
import { AttendanceModule } from './attendance/attendance.module';
import { CompanySettingsModule } from './company-settings/company-settings.module';

@Module({
  imports: [
    AuthModule,
    PrismaModule,
    EventsModule,
    LeaveModule,
    AttendanceModule,
    CompanySettingsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
