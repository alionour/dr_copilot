const app = require('./index').app;
const port = 3000;

app.listen(port, () => {
    console.log(`Local server running at http://localhost:${port}`);
    console.log(`Test downloads page at http://localhost:${port}/downloads.html`);
});
