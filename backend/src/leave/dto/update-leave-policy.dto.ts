import {
  IsBoolean,
  IsString,
  IsOptional,
  IsNumber,
  Min,
} from 'class-validator';

export class UpdateLeavePolicyDto {
  @IsString()
  @IsOptional()
  displayNameAr?: string;

  @IsOptional()
  annualEntitlement?: string | number;

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
