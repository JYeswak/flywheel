import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'

export const metadata = {
  title: { default: 'flywheel Docs', template: '%s — flywheel' },
  description: 'flywheel documentation.'
}

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const pageMap = await getPageMap()

  const navbar = (
    <Navbar
      logo={<b>flywheel</b>}
      projectLink="https://github.com/your-org/flywheel"
    />
  )

  const footer = <Footer>MIT {new Date().getFullYear()} © flywheel.</Footer>

  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head faviconGlyph="📘" />
      <body>
        <Layout
          pageMap={pageMap}
          navbar={navbar}
          footer={footer}
          docsRepositoryBase="https://github.com/your-org/flywheel/blob/main"
          sidebar={{ defaultMenuCollapseLevel: 1, autoCollapse: true }}
          toc={{ float: true }}
          navigation={{ prev: true, next: true }}
          darkMode
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
