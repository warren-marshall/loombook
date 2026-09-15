import { Injectable } from '@nestjs/common';

/**
 * TODO: not implemented. Service-to-service auth via `x-service-token` is
 * wired into JwtAuthGuard but has no real key store yet — every token is
 * rejected until this is built out (e.g. a DB-backed key table + hashing).
 */
@Injectable()
export class ApiKeyService {
  validate(_token: string): Promise<boolean> {
    return Promise.resolve(false);
  }
}
