import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { HrReportsController } from './hr-reports.controller';
import { HrReportsService } from './hr-reports.service';

@Module({
  imports: [PrismaModule],
  controllers: [HrReportsController],
  providers: [HrReportsService],
})
export class HrReportsModule {}
