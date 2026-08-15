import { Test, TestingModule } from '@nestjs/testing';
import { LeaveService } from './leave.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';

import { CompanyTimeService } from '../common/time/company-time.service';

describe('LeaveService', () => {
  let service: LeaveService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeaveService,
        CompanyTimeService,
        {
          provide: PrismaService,
          useValue: {
            leaveBalance: { findMany: jest.fn(), createMany: jest.fn() },
            leaveRequest: { findMany: jest.fn(), create: jest.fn() },
          },
        },
        {
          provide: EventsGateway,
          useValue: {
            emitEntityUpdated: jest.fn(),
          },
        },
        {
          provide: NotificationService,
          useValue: {
            sendPushNotification: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<LeaveService>(LeaveService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
