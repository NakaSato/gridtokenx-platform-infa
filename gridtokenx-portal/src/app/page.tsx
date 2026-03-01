'use client'

import React, { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Shield, Eye, EyeOff, Lock, User } from 'lucide-react'
import { useAuth } from '@/contexts/AuthProvider'
import { createApiClient } from '@/lib/api-client'
import toast from 'react-hot-toast'

export default function AdminLogin() {
  const router = useRouter()
  const { login, logout, user, isAuthenticated, isLoading: authLoading } = useAuth()

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(false)
  const [isLoggingIn, setIsLoggingIn] = useState(false)

  // Auto-redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated && user) {
      if (user.role === 'admin') {
        router.push('/portal')
      } else {
        // Log them out if they are not an admin to break any potential loops
        toast.error('Session ended: Administrator privileges required.')
        logout()
      }
    }
  }, [isAuthenticated, user, router, logout])

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!username || !password) {
      toast.error('Please fill in both username and password.')
      return
    }

    setIsLoggingIn(true)
    try {
      const loginData = await login(username, password, rememberMe)

      // Check if user has admin privileges (client-side)
      if (loginData.user.role !== 'admin') {
        toast.error('Access Denied. Administrator privileges required.')
        setIsLoggingIn(false)
        return
      }

      // Verify backend admin access
      const adminClient = createApiClient(loginData.access_token)
      const adminStats = await adminClient.getAdminStats()

      if (adminStats.error) {
        toast.error('Backend verification failed: Unauthorized or restricted access')
        await logout()
        setIsLoggingIn(false)
        return
      }

      toast.success(`Welcome back, Administrator ${loginData.user.username}`)

      // Delay push slightly to allow toast to render smoothly
      setTimeout(() => {
        router.push('/portal')
      }, 500)
    } catch (error: unknown) {
      console.error('Login error:', error)
      const errorMessage = error instanceof Error ? error.message : 'Invalid credentials or server error.'
      toast.error(`Login failed: ${errorMessage}`)
      setIsLoggingIn(false)
    }
  }

  // If auth state is still loading, show a subtle loading spinner instead of the form
  if (authLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-primary"></div>
          <p className="text-sm text-muted-foreground animate-pulse">Verifying credentials...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-background via-background to-secondary/30 p-4">
      {/* Background Decorators */}
      <div className="fixed top-[-10%] left-[-10%] h-[50%] w-[50%] rounded-full bg-primary/5 blur-[120px] pointer-events-none" />
      <div className="fixed bottom-[-10%] right-[-10%] h-[50%] w-[50%] rounded-full bg-primary/5 blur-[120px] pointer-events-none" />

      <Card className="w-full max-w-md border-primary/20 bg-card/60 backdrop-blur-xl shadow-2xl relative z-10">
        <CardHeader className="space-y-4 pb-6 items-center text-center">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 text-primary border border-primary/20 shadow-inner">
            <Shield className="h-8 w-8" />
          </div>
          <div className="space-y-2">
            <CardTitle className="text-2xl font-bold tracking-tight">Admin Authentication</CardTitle>
            <CardDescription className="text-sm font-medium">
              Secure portal entry for GridTokenX Operations
            </CardDescription>
          </div>
        </CardHeader>

        <form onSubmit={handleLogin}>
          <CardContent className="space-y-5">
            <div className="space-y-2">
              <Label htmlFor="username">Username or Email</Label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-muted-foreground">
                  <User className="h-4 w-4" />
                </div>
                <Input
                  id="username"
                  type="text"
                  placeholder="admin@gridtokenx.com"
                  className="pl-10 h-11 bg-background/50 border-primary/10 focus-visible:ring-primary/30"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  disabled={isLoggingIn}
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">Password</Label>
              </div>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-muted-foreground">
                  <Lock className="h-4 w-4" />
                </div>
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  className="pl-10 pr-10 h-11 bg-background/50 border-primary/10 focus-visible:ring-primary/30"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isLoggingIn}
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-muted-foreground hover:text-foreground transition-colors"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  disabled={isLoggingIn}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox
                id="remember"
                checked={rememberMe}
                onCheckedChange={(c) => setRememberMe(c as boolean)}
                disabled={isLoggingIn}
              />
              <Label htmlFor="remember" className="text-sm font-medium leading-none cursor-pointer">
                Keep me logged in securely
              </Label>
            </div>
          </CardContent>
          <CardFooter className="pt-2 pb-6">
            <Button
              type="submit"
              className="w-full h-11 font-semibold text-[15px] shadow-md transition-all active:scale-[0.98]"
              disabled={isLoggingIn}
            >
              {isLoggingIn ? 'Authenticating...' : 'Enter Admin Portal'}
            </Button>
          </CardFooter>
        </form>
      </Card>
    </div>
  )
}
