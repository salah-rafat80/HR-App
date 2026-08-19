import { IsString, IsNotEmpty } from 'class-validator';

export class AdjustLeaveBalanceDto {
  @IsNotEmpty()
  adjustmentDays: string | number;

  @IsString()
  @IsNotEmpty()
  reason: string;
}
