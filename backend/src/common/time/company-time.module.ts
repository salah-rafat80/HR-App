import { Global, Module } from '@nestjs/common';
import { CompanyTimeService } from './company-time.service';

@Global()
@Module({
  providers: [CompanyTimeService],
  exports: [CompanyTimeService],
})
export class CompanyTimeModule {}
