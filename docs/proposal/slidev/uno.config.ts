import { defineConfig, presetUno, presetAttributify, presetIcons, presetTypography, presetWebFonts } from 'unocss'

export default defineConfig({
    presets: [
        presetUno(),
        presetAttributify(),
        presetIcons(),
        presetTypography(),
        presetWebFonts({
            fonts: {
                sans: 'Inter',
                mono: 'JetBrains Mono',
                kanit: 'Kanit',
            },
        }),
    ],
    theme: {
        colors: {
            solana: {
                green: '#14f195',
                purple: '#9945FF',
                black: '#000000',
                dark: '#0f172a',
            },
        },
    },
    shortcuts: {
        'cyber-card': 'p-6 rounded-xl border border-white/10 bg-black/40 backdrop-blur-md shadow-lg hover:border-solana-green/30 transition-all duration-300',
        'terminal-block': 'font-mono text-xs p-4 rounded-lg bg-black border border-solana-purple/20 shadow-[0_0_20px_rgba(153,69,255,0.05)]',
        'mono-label': 'font-mono text-[10px] uppercase tracking-wider opacity-50',
        'solana-glow': 'shadow-[0_0_30px_rgba(20,241,149,0.15)]',
    },
})
