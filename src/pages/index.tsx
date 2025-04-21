import Head from 'next/head';

export default function Home() {
  return (
    <>
      <Head>
        <title>JobsStory | منصة الفيديو الوظيفي</title>
      </Head>
      <main className="flex min-h-screen flex-col items-center justify-center bg-gray-50">
        <h1 className="text-4xl font-bold mb-4 text-blue-700">JobsStory</h1>
        <p className="text-lg text-gray-700">منصة التوظيف بالفيديوهات القصيرة</p>
      </main>
    </>
  );
}
