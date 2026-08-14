import { Type } from 'class-transformer';
import { IsDateString, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RequestOvertimeDto {
  @IsDateString(
    {},
    { message: 'requestedStartAt must be a valid ISO-8601 date-time' },
  )
  requestedStartAt: string;

  @IsDateString(
    {},
    { message: 'requestedEndAt must be a valid ISO-8601 date-time' },
  )
  requestedEndAt: string;

  @Type(() => String)
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  reason: string;
}
