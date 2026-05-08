<script setup lang="ts">
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/vue'

// S-02 削除確認モーダル（画面設計書 4-2）
// Headless UI Vue の Dialog を使用（既導入: package.json）
defineProps<{
  open: boolean
  recipeTitle: string
  busy?: boolean
}>()

const emit = defineEmits<{
  cancel: []
  confirm: []
}>()
</script>

<template>
  <Dialog
    :open="open"
    class="relative z-50"
    @close="emit('cancel')"
  >
    <div class="fixed inset-0 bg-black/40" aria-hidden="true" />

    <div class="fixed inset-0 flex items-center justify-center p-4">
      <DialogPanel class="w-full max-w-md rounded-lg bg-white p-6 shadow-xl">
        <DialogTitle class="text-lg font-bold text-gray-900">
          レシピを削除しますか？
        </DialogTitle>

        <p class="mt-3 text-sm text-gray-600">
          「{{ recipeTitle }}」を削除します。<br>
          この操作は取り消せません。
        </p>

        <div class="mt-6 flex justify-end gap-3">
          <button
            type="button"
            :disabled="busy"
            class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
            @click="emit('cancel')"
          >
            キャンセル
          </button>
          <button
            type="button"
            :disabled="busy"
            class="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
            @click="emit('confirm')"
          >
            {{ busy ? '削除中...' : '削除する' }}
          </button>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template>
