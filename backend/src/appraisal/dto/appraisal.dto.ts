import { IsString, IsNotEmpty, IsArray, ValidateNested, IsDateString, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class StartCycleDto {
  @IsString()
  @IsNotEmpty()
  label: string;

  @IsDateString()
  @IsNotEmpty()
  dueDate: string;
}

export class SelfAppraisalAnswerItemDto {
  @IsString()
  @IsNotEmpty()
  id: string; // questionId

  @IsString()
  @IsNotEmpty()
  questionText: string;

  @IsString()
  @IsOptional()
  answerText?: string;
}

export class SubmitSelfAppraisalDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SelfAppraisalAnswerItemDto)
  answers: SelfAppraisalAnswerItemDto[];
}

export class SubmitPeerFeedbackDto {
  @IsString()
  @IsNotEmpty()
  colleagueId: string;

  @IsString()
  @IsNotEmpty()
  feedbackText: string;
}
