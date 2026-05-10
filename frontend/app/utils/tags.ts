/**
 * タグ入力文字列を string array に変換する（#112）
 *
 * 区切り文字: 半角カンマ , / 全角カンマ ， / 読点 、
 * 空白は trim、空文字は除外。重複排除は backend 側で実施。
 *
 * 例:
 *   parseTagsInput("和食, 簡単,夕食") → ["和食", "簡単", "夕食"]
 *   parseTagsInput("和食、和食、 ") → ["和食", "和食"]   (重複は backend で正規化)
 */
export function parseTagsInput(raw: string): string[] {
  return raw
    .split(/[,，、]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
}

/**
 * 既存タグ配列を編集 input の初期値文字列に変換する（#112）
 */
export function formatTagsInput(tags: string[]): string {
  return tags.join(', ')
}
