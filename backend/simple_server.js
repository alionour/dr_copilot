const express = require('express');
const path = require('path');
const app = express();
const port = 3000;

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

// Start the server
app.listen(port, () => {
    console.log(`\n✅ 3D Asset Server running at http://localhost:${port}`);
    console.log(`   - 3D View: http://localhost:${port}/body_chart_3d.html`);
    console.log(`   - Model:   http://localhost:${port}/models/human_body.glb`);
    console.log('\nKeep this terminal open while testing Option A (WebView).');
});
