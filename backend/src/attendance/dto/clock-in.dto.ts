import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { AttendanceStatus } from '@prisma/client';

export class ClockInDto {
  @IsString()
  @IsNotEmpty()
  locationLabel: string;

  @IsEnum(AttendanceStatus)
  mode: AttendanceStatus;
}
