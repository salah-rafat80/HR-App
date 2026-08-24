import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
} from 'class-validator';

export class SubmitSelfAssessmentDto {
  @IsString()
  @IsNotEmpty()
  text: string;
}

export class AssignKpiDto {
  @IsString()
  @IsNotEmpty()
  memberId: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  departmentObjective?: string;

  @IsNumber()
  @IsOptional()
  @IsPositive()
  targetValue?: number;
}
