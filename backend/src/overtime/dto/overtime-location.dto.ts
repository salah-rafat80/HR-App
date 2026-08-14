import { IsNumber, IsPositive, Max, Min } from 'class-validator';

export class OvertimeLocationDto {
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

  @IsNumber(
    { allowNaN: false, allowInfinity: false },
    { message: 'accuracy must be a finite number' },
  )
  @IsPositive({ message: 'accuracy must be a positive number' })
  @Max(50, { message: 'GPS accuracy too low — must be ≤ 50 m' })
  accuracy: number;
}
