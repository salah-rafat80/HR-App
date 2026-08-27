import { Test, TestingModule } from '@nestjs/testing';
import { CommunicationController } from './communication.controller';
import { CommunicationService } from './communication.service';
import { RolesGuard } from '../auth/roles.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Role } from '../auth/roles.enum';
import { Reflector } from '@nestjs/core';
import {
  ValidationPipe,
  ExecutionContext,
  BadRequestException,
} from '@nestjs/common';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';

describe('CommunicationController', () => {
  let controller: CommunicationController;
  let service: {
    create: jest.Mock;
    findAll: jest.Mock;
  };
  let reflector: Reflector;

  beforeEach(async () => {
    service = {
      create: jest.fn(),
      findAll: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CommunicationController],
      providers: [{ provide: CommunicationService, useValue: service }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<CommunicationController>(CommunicationController);
    reflector = new Reflector();
  });

  describe('create', () => {
    it('should assign authorId from the request user to service call', async () => {
      const dto = { title: 'Test', content: 'Test content' };
      const req = { user: { userId: 'auth-user-id' } };

      await controller.create(dto, req);

      expect(service.create).toHaveBeenCalledWith(dto, 'auth-user-id');
    });

    it('should reject non-empty department', async () => {
      const dto = { title: 'Test', content: 'Test content', department: 'HR' };
      const req = { user: { userId: 'auth-user-id' } };

      await expect(
        controller.create(dto as CreateAnnouncementDto, req),
      ).rejects.toThrow(BadRequestException);
    });

    it('should be decorated with @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)', () => {
      /* eslint-disable-next-line @typescript-eslint/unbound-method */
      const roles = reflector.get<Role[]>('roles', controller.create);

      expect(roles).toBeDefined();
      expect(roles).toHaveLength(3);
      expect(roles).toContain(Role.hr);
      expect(roles).toContain(Role.hrAdmin);
      expect(roles).toContain(Role.superAdmin);
      expect(roles).not.toContain(Role.manager);
      expect(roles).not.toContain(Role.employee);
    });
  });

  describe('findAll', () => {
    it('should return all announcements', async () => {
      service.findAll.mockResolvedValue([]);
      const req = { user: { userId: 'auth-user-id' } };
      const result = await controller.findAll(req);
      expect(result).toEqual([]);
      expect(service.findAll).toHaveBeenCalledWith('auth-user-id');
    });
  });

  describe('RolesGuard Actual Execution', () => {
    let rolesGuard: RolesGuard;

    beforeEach(() => {
      rolesGuard = new RolesGuard(reflector);
    });

    it('should deny employee, manager, and team_lead', () => {
      const createExecutionContext = (role: string): ExecutionContext => {
        return {
          // eslint-disable-next-line @typescript-eslint/unbound-method
          getHandler: () => CommunicationController.prototype.create,
          getClass: () => CommunicationController,
          switchToHttp: () => ({
            getRequest: () => ({ user: { role } }),
          }),
        } as unknown as ExecutionContext;
      };

      expect(
        rolesGuard.canActivate(createExecutionContext(Role.employee)),
      ).toBe(false);
      expect(rolesGuard.canActivate(createExecutionContext(Role.manager))).toBe(
        false,
      );
      expect(rolesGuard.canActivate(createExecutionContext('team_lead'))).toBe(
        false,
      );
    });

    it('should allow hr, hrAdmin, superAdmin', () => {
      const createExecutionContext = (role: string): ExecutionContext => {
        return {
          // eslint-disable-next-line @typescript-eslint/unbound-method
          getHandler: () => CommunicationController.prototype.create,
          getClass: () => CommunicationController,
          switchToHttp: () => ({
            getRequest: () => ({ user: { role } }),
          }),
        } as unknown as ExecutionContext;
      };

      expect(rolesGuard.canActivate(createExecutionContext(Role.hr))).toBe(
        true,
      );
      expect(rolesGuard.canActivate(createExecutionContext(Role.hrAdmin))).toBe(
        true,
      );
      expect(
        rolesGuard.canActivate(createExecutionContext(Role.superAdmin)),
      ).toBe(true);
    });
  });

  describe('ValidationPipe Execution', () => {
    let target: ValidationPipe;

    beforeEach(() => {
      target = new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      });
    });

    it('should reject payload with authorId', async () => {
      const payload = {
        title: 'Valid',
        content: 'Valid content',
        authorId: 'injected-author',
      };
      await expect(
        target.transform(payload, {
          type: 'body',
          metatype: CreateAnnouncementDto,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject whitespace-only title and content after transform', async () => {
      const payload = {
        title: '   ',
        content: '   ',
      };
      await expect(
        target.transform(payload, {
          type: 'body',
          metatype: CreateAnnouncementDto,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should successfully transform valid input', async () => {
      const payload = {
        title: '  Trim Me  ',
        content: '  Trim Me Content  ',
      };
      const result = (await target.transform(payload, {
        type: 'body',
        metatype: CreateAnnouncementDto,
      })) as CreateAnnouncementDto;
      expect(result.title).toBe('Trim Me');
      expect(result.content).toBe('Trim Me Content');
      expect(result.department).toBeUndefined();
    });
  });
});
