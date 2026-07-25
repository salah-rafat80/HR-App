import { WebSocketGateway, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket, ...args: any[]) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  // Generic broadcast
  emitEntityUpdated(entityType: string, action: string, data?: any) {
    this.server.emit('entity.updated', {
      entity: entityType,
      action,
      data,
      timestamp: new Date().toISOString(),
    });
  }

  // Targeted to a specific user
  emitToUser(userId: string, action: string, data?: any) {
    this.server.emit(`entity.updated.${userId}`, {
      entity: 'LeaveRequest',
      action,
      data,
      timestamp: new Date().toISOString(),
    });
  }

  // Targeted to a role
  emitToRole(role: string, action: string, data?: any) {
    this.server.emit(`entity.updated.${role}`, {
      entity: 'LeaveRequest',
      action,
      data,
      timestamp: new Date().toISOString(),
    });
  }
}
