import { defineKatexSetup } from '@slidev/types'

export default defineKatexSetup(() => {
    return {
        maxExpand: 2000,
        strict: 'warn',
        output: 'htmlAndMathml',
        throwOnError: false,
        errorColor: '#cc0000',
        macros: {
            // Add your custom macros here
            // "\\RR": "\\mathbb{R}",
        },
        trust: (context) => ['\\url', '\\href'].includes(context.command),
    }
})
