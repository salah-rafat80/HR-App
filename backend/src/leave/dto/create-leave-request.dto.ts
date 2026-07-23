import { IsEnum, IsBoolean, IsString, IsNotEmpty, IsOptional, IsDateString } from 'class-validator';

export enum LeaveType {
  annual = 'annual',
  sick = 'sick',
  emergency = 'emergency',
  maternityPaternity = 'maternityPaternity',
  unpaid = 'unpaid',
  study = 'study',
  hajj = 'hajj',
  bereavement = 'bereavement',
}

export enum HalfDayPeriod {
  morning = 'morning',
  afternoon = 'afternoon',
}

export class CreateLeaveRequestDto {
  @IsEnum(LeaveType)
  @IsNotEmpty()
  type: LeaveType;

  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @IsBoolean()
  @IsNotEmpty()
  isHalfDay: boolean;

  @IsEnum(HalfDayPeriod)
  @IsOptional()
  halfDayPeriod?: HalfDayPeriod;

  @IsString()
  @IsNotEmpty()
  reason: string;

  @IsBoolean()
  @IsOptional()
  hasAttachment?: boolean;
}
