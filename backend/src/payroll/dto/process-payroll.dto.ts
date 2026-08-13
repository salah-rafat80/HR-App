import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { Transform } from 'class-transformer';

export class ProcessPayrollDto {
  @IsNotEmpty({ message: 'Period label is required' })
  @IsString()
  @MaxLength(50, { message: 'Period label is too long' })
  @Transform(({ value }: { value: unknown }): unknown =>
    typeof value === 'string' ? value.trim() : value,
  )
  periodLabel!: string;
}
