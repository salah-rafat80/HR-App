import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { LoginDto } from './login.dto';

describe('LoginDto', () => {
  it('should validate and normalize valid employeeCode and password', async () => {
    const plain = {
      employeeCode: ' emp-0001 ',
      password: 'securePassword123',
    };
    const dto = plainToInstance(LoginDto, plain);
    const errors = await validate(dto);

    expect(errors.length).toBe(0);
    expect(dto.employeeCode).toBe('EMP-0001');
    expect(dto.password).toBe('securePassword123');
  });

  it('should fail validation when employeeCode is missing', async () => {
    const plain = { password: 'securePassword123' };
    const dto = plainToInstance(LoginDto, plain);
    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('employeeCode');
  });

  it('should fail validation when password is too short', async () => {
    const plain = { employeeCode: 'EMP-0001', password: '123' };
    const dto = plainToInstance(LoginDto, plain);
    const errors = await validate(dto);

    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('password');
  });
});
