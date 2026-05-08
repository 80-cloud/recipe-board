// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  // Tailwind CSS 統合
  modules: ['@nuxtjs/tailwindcss'],

  // 開発サーバーのポート（Rails 3000 と衝突回避のため 3001）
  // CLAUDE.md セクション 10 ポート競合ルールに従う
  devServer: {
    port: 3001,
  },

  // Rails API への接続情報（実装時に環境変数で上書き）
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:3000/api',
    },
  },
})
