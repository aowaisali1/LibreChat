// api/types/express/index.d.ts

import type { User as DBUser } from '../../models/user';

declare global {
  namespace Express {
    interface User extends DBUser {}
  }
}
