import { IsNotEmpty, IsString } from 'class-validator';

export class CreatePayrollRunDto {
  @IsString()
  @IsNotEmpty()
  periodLabel: string;
}
