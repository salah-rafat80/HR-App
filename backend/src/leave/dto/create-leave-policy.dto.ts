import {
  IsEnum,
  IsBoolean,
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
} from 'class-validator';
import { LeaveType } from './create-leave-request.dto';

export class CreateLeavePolicyDto {
  @IsEnum(LeaveType)
  @IsNotEmpty()
  type: LeaveType;

  @IsString()
  @IsNotEmpty()
  displayNameAr: string;

  @IsNotEmpty()
  annualEntitlement: string | number;

  @IsBoolean()
  @IsOptional()
  isPaid?: boolean;

  @IsBoolean()
  @IsOptional()
  requiresBalance?: boolean;

  @IsBoolean()
  @IsOptional()
  allowHalfDay?: boolean;

  @IsNumber()
  @Min(0)
  @IsOptional()
  minimumNoticeDays?: number;

  @IsBoolean()
  @IsOptional()
  requiresReason?: boolean;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
