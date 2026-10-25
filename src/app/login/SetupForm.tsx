// Tofu: this file is Tofu's addition (see TOFU.md and src/app/api/auth/setup/route.ts).
import {
  Column,
  Form,
  FormButtons,
  FormField,
  FormSubmitButton,
  Heading,
  Icon,
  PasswordField,
  Text,
  TextField,
} from '@umami/react-zen';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { useApi, useMessages } from '@/components/hooks';
import { Logo } from '@/components/svg';
import { setClientAuthToken } from '@/lib/client';
import { setUser } from '@/store/app';

export function SetupForm({ onDone }: { onDone: () => void }) {
  const { t, labels } = useMessages();
  const { post } = useApi();
  const router = useRouter();
  const [error, setError] = useState<string>();

  const handleSubmit = async (data: { username: string; password: string }) => {
    setError(undefined);

    try {
      await post('/auth/setup', data);
    } catch (e: any) {
      if (e?.code === 'setup-done') {
        onDone();
        return;
      }
      setError(e?.message || 'The account could not be created.');
      return;
    }

    try {
      const response = await post('/auth/login', data);
      setClientAuthToken(response.token);
      setUser(response.user);
      router.push('/');
    } catch {
      onDone();
    }
  };

  return (
    <Column justifyContent="center" alignItems="center" gap="6" style={{ maxWidth: 360 }}>
      <Icon size="lg">
        <Logo />
      </Icon>
      <Heading>umami</Heading>
      <Heading size="lg">Create the administrator account</Heading>
      <Text align="center">
        This app has no account yet. The first person to finish this form becomes its
        administrator and can add other people later, under Settings, Users.
      </Text>
      <Form
        onSubmit={handleSubmit}
        error={error}
        defaultValues={{ username: '', password: '' }}
        style={{ minWidth: 300 }}
      >
        <FormField
          label={t(labels.username)}
          data-test="setup-username"
          name="username"
          rules={{ required: t(labels.required) }}
        >
          <TextField autoComplete="username" />
        </FormField>

        <FormField
          label={`${t(labels.password)} (at least 8 characters)`}
          data-test="setup-password"
          name="password"
          rules={{
            required: t(labels.required),
            minLength: { value: 8, message: 'At least 8 characters' },
          }}
        >
          <PasswordField autoComplete="new-password" />
        </FormField>
        <FormButtons>
          <FormSubmitButton data-test="setup-submit" variant="primary" style={{ flex: 1 }}>
            Create account
          </FormSubmitButton>
        </FormButtons>
      </Form>
    </Column>
  );
}
