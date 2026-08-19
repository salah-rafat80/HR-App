import { IsEnum, IsString, IsNotEmpty, IsNumber, Min } from 'class-validator';
import { LeaveType } from './create-leave-request.dto';

export class CreateLeaveBalanceDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsEnum(LeaveType)
  @IsNotEmpty()
  type: LeaveType;

  @IsNumber()
  @Min(2000)
  @IsNotEmpty()
  year: number;

  @IsNotEmpty()
  entitledDays: string | number;
}
