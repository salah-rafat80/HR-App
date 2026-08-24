import { Module } from '@nestjs/common';
import { LeaveService } from './leave.service';
import { LeaveCalendarService } from './leave-calendar.service';
import { LeaveController } from './leave.controller';

import { PrismaModule } from '../prisma/prisma.module';
import { EventsModule } from '../events/events.module';
import { NotificationModule } from '../notifications/notification.module';
import { CompanyTimeModule } from '../common/time/company-time.module';

@Module({
  imports: [PrismaModule, EventsModule, NotificationModule, CompanyTimeModule],
  providers: [LeaveService, LeaveCalendarService],
  controllers: [LeaveController],
  exports: [LeaveService, LeaveCalendarService],
})
export class LeaveModule {}
