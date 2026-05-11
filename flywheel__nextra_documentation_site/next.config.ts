import nextra from 'nextra'

const withNextra = nextra({
  latex: true,
  defaultShowCopyCode: true,
  search: {
    codeblocks: false
  },
  contentDirBasePath: '/'
})

export default withNextra({
  reactStrictMode: true
})
