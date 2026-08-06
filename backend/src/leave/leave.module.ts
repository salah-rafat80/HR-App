import { Module } from '@nestjs/common';
import { LeaveService } from './leave.service';
import { LeaveController } from './leave.controller';

import { PrismaModule } from '../prisma/prisma.module';
import { EventsModule } from '../events/events.module';
import { NotificationModule } from '../notifications/notification.module';

@Module({
  imports: [PrismaModule, EventsModule, NotificationModule],
  providers: [LeaveService],
  controllers: [LeaveController]
})
export class LeaveModule {}

