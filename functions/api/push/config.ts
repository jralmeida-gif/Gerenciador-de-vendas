interface Env {
  VAPID_PUBLIC_KEY: string;
}

export const onRequestGet: PagesFunction<Env> = ({ env }) => {
  return Response.json({ publicKey: env.VAPID_PUBLIC_KEY });
};
