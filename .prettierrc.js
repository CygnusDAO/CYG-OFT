module.exports = {
    trailingComma: "all",
    tabWidth: 4,
    semi: true,
    singleQuote: false,
    printWidth: 160,
    overrides: [
        {
            files: "*.sol",
            options: {
                printWidth: 140,
            },
        },
    ],
};
