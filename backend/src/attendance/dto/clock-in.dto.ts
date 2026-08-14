import { IsEnum, IsNumber, Min, Max, IsPositive } from 'class-validator';
import { AttendanceStatus } from '@prisma/client';

export class ClockInDto {
  /** locationLabel is derived server-side only — never accepted from the client. */

  @IsEnum(AttendanceStatus)
  mode: AttendanceStatus;

  @IsNumber(
    { allowNaN: false, allowInfinity: false },
    { message: 'lat must be a finite number' },
  )
  @Min(-90, { message: 'lat must be between -90 and 90' })
  @Max(90, { message: 'lat must be between -90 and 90' })
  lat: number;

  @IsNumber(
    { allowNaN: false, allowInfinity: false },
    { message: 'lng must be a finite number' },
  )
  @Min(-180, { message: 'lng must be between -180 and 180' })
  @Max(180, { message: 'lng must be between -180 and 180' })
  lng: number;

  /** Maximum allowed GPS accuracy: 50 metres. */
  @IsNumber(
    { allowNaN: false, allowInfinity: false },
    { message: 'accuracy must be a finite number' },
  )
  @IsPositive({ message: 'accuracy must be a positive number' })
  @Max(50, { message: 'GPS accuracy too low — must be ≤ 50 m' })
  accuracy: number;
}
