'use client'

import { AuthProvider } from '@/contexts/AuthProvider'
import Connectionprovider from '@/contexts/connectionprovider'
import QueryProvider from './QueryProvider'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <QueryProvider>
      <Connectionprovider>
        <AuthProvider>
          {children}
        </AuthProvider>
      </Connectionprovider>
    </QueryProvider>
  )
}
