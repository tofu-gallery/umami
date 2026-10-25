'use client';
import { Column, Loading } from '@umami/react-zen';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { useApi, useLoginQuery } from '@/components/hooks';
import { LoginForm } from './LoginForm';
import { PropsWithChildren } from 'react';
// Tofu: while the app has no account, the first visitor creates its administrator (see TOFU.md).
import { SetupForm } from './SetupForm';

export function LoginPageWrapper({ children }: PropsWithChildren) {
  const { user, isLoading } = useLoginQuery();
  const router = useRouter();

  useEffect(() => {
    if (user) {
      router.replace('/');
    }
  }, [user, router]);

  if (isLoading || user) {
    return <Loading placement="absolute" />;
  }

  return (
    <Column
      alignItems="center"
      justifyContent="flex-start"
      height="100vh"
      backgroundColor="surface-raised"
      style={{ paddingTop: '15vh' }}
    >
      {children}
    </Column>
  );
}

// Tofu: the login form, or the first-run form while the app has no account (src/app/api/auth/setup/route.ts).
function LoginOrSetup() {
  const { get, useQuery } = useApi();
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['auth:setup'],
    queryFn: () => get('/auth/setup'),
    retry: false,
  });

  if (isLoading) {
    return <Loading placement="absolute" />;
  }

  return data?.needed ? <SetupForm onDone={() => refetch()} /> : <LoginForm />;
}

export function LoginPage() {
  return (
    <LoginPageWrapper>
      <LoginOrSetup />
    </LoginPageWrapper>
  );
}
