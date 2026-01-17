#!/usr/bin/env node

/**
 * Firestore Schema Documentation Generator
 * 
 * This script analyzes Firestore collections and generates comprehensive
 * schema documentation showing all fields, types, and structures.
 * 
 * Usage:
 *   node scripts/generate_firestore_schema.js --mode=export
 *   node scripts/generate_firestore_schema.js --mode=live
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const mode = args.find(arg => arg.startsWith('--mode='))?.split('=')[1] || 'export';

const EXPORTED_FILE = path.join(__dirname, '..', 'exported_firestore.json');
const OUTPUT_FILE = path.join(__dirname, '..', 'docs', 'FIRESTORE_SCHEMA.md');

/**
 * Analyze a collection's documents to infer schema
 */
function analyzeCollection(collectionName, documents) {
    const fieldStats = new Map();
    const totalDocs = documents.length;

    // Analyze each document
    documents.forEach(doc => {
        Object.entries(doc).forEach(([fieldName, value]) => {
            if (!fieldStats.has(fieldName)) {
                fieldStats.set(fieldName, {
                    count: 0,
                    types: new Set(),
                    samples: [],
                });
            }

            const stats = fieldStats.get(fieldName);
            stats.count++;

            const type = inferType(value);
            stats.types.add(type);

            // Keep up to 3 sample values
            if (stats.samples.length < 3 && value !== null && value !== undefined) {
                stats.samples.push(formatSampleValue(value, type));
            }
        });
    });

    // Convert to sorted array with metadata
    const fields = Array.from(fieldStats.entries()).map(([name, stats]) => {
        const frequency = stats.count / totalDocs;
        const isRequired = frequency > 0.95; // Consider required if in 95%+ of documents
        const types = Array.from(stats.types).join(' | ');

        return {
            name,
            types,
            required: isRequired,
            frequency: (frequency * 100).toFixed(1) + '%',
            samples: stats.samples,
        };
    });

    // Sort by required first, then alphabetically
    fields.sort((a, b) => {
        if (a.required !== b.required) return b.required - a.required;
        return a.name.localeCompare(b.name);
    });

    return {
        collectionName,
        documentCount: totalDocs,
        fields,
    };
}

/**
 * Infer the type of a value
 */
function inferType(value) {
    if (value === null) return 'null';
    if (value === undefined) return 'undefined';
    if (Array.isArray(value)) {
        if (value.length === 0) return 'array';
        const itemTypes = new Set(value.map(inferType));
        return `array<${Array.from(itemTypes).join(' | ')}>`;
    }

    const type = typeof value;

    if (type === 'object') {
        // Check for special types
        if (value._seconds !== undefined || value._nanoseconds !== undefined) {
            return 'Timestamp';
        }
        return 'object';
    }

    return type;
}

/**
 * Format a sample value for display
 */
function formatSampleValue(value, type) {
    if (type === 'string') {
        return value.length > 50 ? `"${value.substring(0, 47)}..."` : `"${value}"`;
    }
    if (type === 'Timestamp') {
        if (value._seconds) {
            return new Date(value._seconds * 1000).toISOString().split('T')[0];
        }
        return 'Timestamp';
    }
    if (Array.isArray(value)) {
        return `[${value.length} items]`;
    }
    if (typeof value === 'object') {
        return `{${Object.keys(value).length} fields}`;
    }
    return String(value);
}

/**
 * Generate markdown documentation
 */
function generateMarkdown(schemas) {
    const lines = [];

    // Header
    lines.push('# Firestore Database Schema');
    lines.push('');
    lines.push('> Auto-generated documentation of the Firestore database schema.');
    lines.push('> Last updated: ' + new Date().toISOString().split('T')[0]);
    lines.push('');

    // Overview
    lines.push('## Overview');
    lines.push('');
    lines.push(`This database contains **${schemas.length} collections** with the following structure:`);
    lines.push('');

    // Table of contents
    lines.push('### Collections');
    lines.push('');
    schemas.forEach(schema => {
        lines.push(`- [${schema.collectionName}](#${schema.collectionName.toLowerCase()}) (${schema.documentCount} documents)`);
    });
    lines.push('');
    lines.push('---');
    lines.push('');

    // Detailed schemas
    schemas.forEach(schema => {
        lines.push(`## ${schema.collectionName}`);
        lines.push('');
        lines.push(`**Document Count:** ${schema.documentCount}`);
        lines.push('');

        if (schema.fields.length === 0) {
            lines.push('*No fields found in this collection.*');
            lines.push('');
            return; // Skip to next collection
        }

        // Fields table
        lines.push('### Fields');
        lines.push('');
        lines.push('| Field Name | Type | Required | Frequency | Sample Values |');
        lines.push('|------------|------|----------|-----------|---------------|');

        schema.fields.forEach(field => {
            const required = field.required ? '✓' : '';
            const samples = field.samples.slice(0, 2).join(', ');
            lines.push(`| \`${field.name}\` | ${field.types} | ${required} | ${field.frequency} | ${samples} |`);
        });

        lines.push('');

        // Sample document
        lines.push('### Sample Document Structure');
        lines.push('');
        lines.push('```json');
        const sampleDoc = {};
        schema.fields.slice(0, 10).forEach(field => {
            const sampleValue = field.samples[0] || 'null';
            sampleDoc[field.name] = sampleValue;
        });
        lines.push(JSON.stringify(sampleDoc, null, 2));
        lines.push('```');
        lines.push('');
        lines.push('---');
        lines.push('');
    });

    // Footer
    lines.push('## Notes');
    lines.push('');
    lines.push('- **Required**: Fields present in 95% or more of documents');
    lines.push('- **Frequency**: Percentage of documents containing this field');
    lines.push('- **Type**: Inferred from document data (may include union types)');
    lines.push('');

    return lines.join('\n');
}

/**
 * Main execution
 */
async function main() {
    console.log('🔍 Firestore Schema Documentation Generator');
    console.log('Mode:', mode);
    console.log('');

    let data;

    if (mode === 'export') {
        // Read from exported file
        console.log('📂 Reading from:', EXPORTED_FILE);

        if (!fs.existsSync(EXPORTED_FILE)) {
            console.error('❌ Error: exported_firestore.json not found!');
            console.error('Please run a Firestore export first or use --mode=live');
            process.exit(1);
        }

        const fileContent = fs.readFileSync(EXPORTED_FILE, 'utf8');
        data = JSON.parse(fileContent);
    } else if (mode === 'live') {
        // Fetch from live Firestore
        console.log('🔥 Fetching from live Firestore...');
        const admin = require('firebase-admin');
        const serviceAccount = require('../backend/drcopilot-bfc9e-firebase-adminsdk-fbsvc-2fb5aba08a.json');

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });

        const db = admin.firestore();
        data = {};

        // Get all collections
        const collections = await db.listCollections();

        for (const collection of collections) {
            console.log(`  Fetching ${collection.id}...`);
            const snapshot = await collection.get();
            data[collection.id] = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data(),
            }));
        }
    } else {
        console.error('❌ Invalid mode. Use --mode=export or --mode=live');
        process.exit(1);
    }

    // Analyze all collections
    console.log('📊 Analyzing schema...');
    const schemas = [];

    Object.entries(data).forEach(([collectionName, documents]) => {
        if (Array.isArray(documents) && documents.length > 0) {
            console.log(`  - ${collectionName}: ${documents.length} documents`);
            const schema = analyzeCollection(collectionName, documents);
            schemas.push(schema);
        }
    });

    // Sort schemas alphabetically
    schemas.sort((a, b) => a.collectionName.localeCompare(b.collectionName));

    // Generate markdown
    console.log('');
    console.log('📝 Generating documentation...');
    const markdown = generateMarkdown(schemas);

    // Write to file
    fs.writeFileSync(OUTPUT_FILE, markdown, 'utf8');

    console.log('');
    console.log('✅ Schema documentation generated!');
    console.log('📄 Output:', OUTPUT_FILE);
    console.log('');
    console.log('Summary:');
    console.log(`  - ${schemas.length} collections analyzed`);
    console.log(`  - ${schemas.reduce((sum, s) => sum + s.documentCount, 0)} total documents`);
    console.log(`  - ${schemas.reduce((sum, s) => sum + s.fields.length, 0)} unique fields`);
}

// Run the script
main().catch(error => {
    console.error('❌ Error:', error.message);
    process.exit(1);
});
