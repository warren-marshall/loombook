import { Injectable, UnauthorizedException } from '@nestjs/common';
import type { Session } from '@supabase/supabase-js';
import { SupabaseService } from '../supabase/supabase.service';

export interface Tokens {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  constructor(private readonly supabase: SupabaseService) {}

  async login(email: string, password: string): Promise<Tokens> {
    const { data, error } = await this.supabase
      .anonClient()
      .auth.signInWithPassword({ email, password });

    if (error || !data.session) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.toTokens(data.session);
  }

  async refresh(refreshToken: string): Promise<Tokens> {
    const { data, error } = await this.supabase
      .anonClient()
      .auth.refreshSession({ refresh_token: refreshToken });

    if (error || !data.session) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    return this.toTokens(data.session);
  }

  private toTokens(session: Session): Tokens {
    return {
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
    };
  }
}
