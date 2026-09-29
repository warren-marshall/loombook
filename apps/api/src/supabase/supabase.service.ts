import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const STATELESS = { auth: { persistSession: false, autoRefreshToken: false } };

@Injectable()
export class SupabaseService {
  /** Service-role client for the auth admin API. Never sign a user in with it. */
  readonly admin: SupabaseClient;

  private readonly url: string;
  private readonly anonKey: string;

  constructor(config: ConfigService) {
    this.url = config.getOrThrow<string>('SUPABASE_URL');
    this.anonKey = config.getOrThrow<string>('SUPABASE_ANON_KEY');
    this.admin = createClient(
      this.url,
      config.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY'),
      STATELESS,
    );
  }

  /**
   * A fresh anon client per call: supabase-js keeps the signed-in session on
   * the client, so a shared one would leak one user's session into the next
   * request.
   */
  anonClient(): SupabaseClient {
    return createClient(this.url, this.anonKey, STATELESS);
  }
}
