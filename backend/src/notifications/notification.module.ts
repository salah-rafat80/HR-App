import { Module } from '@nestjs/common';
import { NotificationService } from './notification.service';

import { PrismaModule } from '../prisma/prisma.module';
import { NotificationController } from './notification.controller';

@Module({
  imports: [PrismaModule],
  controllers: [NotificationController],
  providers: [NotificationService],
  exports: [NotificationService],
})
export class NotificationModule {}
