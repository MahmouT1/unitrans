const express = require('express');
const mongoose = require('mongoose');
const { ObjectId } = require('mongodb');
const Transportation = require('../models/Transportation');

const router = express.Router();

// GET - Get all transportation schedules
router.get('/', async (req, res) => {
    try {
        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Try to get data from transportation collection
        const transportationCollection = db.collection('transportation');
        const transportation = await transportationCollection
            .find({})
            .sort({ createdAt: -1 })
            .toArray();

        res.json({
            success: true,
            transportation: transportation || [],
            count: transportation.length
        });

    } catch (error) {
        console.error('Get transportation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get transportation schedules',
            error: error.message
        });
    }
});

// POST - Create new transportation schedule
router.post('/', async (req, res) => {
    try {
        const {
            name,
            time,
            location,
            googleMapsLink,
            parking,
            capacity,
            status,
            days,
            description
        } = req.body;

        // Validate required fields
        if (!name || !time || !location || !parking || !capacity) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: name, time, location, parking, capacity'
            });
        }

        // Validate capacity
        if (parseInt(capacity) < 1) {
            return res.status(400).json({
                success: false,
                message: 'Capacity must be at least 1'
            });
        }

        // Validate Google Maps link if provided
        if (googleMapsLink && !googleMapsLink.match(/^https?:\/\/.+/)) {
            return res.status(400).json({
                success: false,
                message: 'Google Maps link must be a valid URL'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Create transportation schedule object
        const transportationData = {
            name: name.trim(),
            time,
            location: location.trim(),
            googleMapsLink: googleMapsLink ? googleMapsLink.trim() : '',
            parking: parking.trim(),
            capacity: parseInt(capacity),
            status: status || 'Active',
            days: Array.isArray(days) ? days : [],
            description: description ? description.trim() : '',
            createdBy: new ObjectId(), // Default admin ObjectId
            createdAt: new Date(),
            updatedAt: new Date()
        };

        // Insert into database
        const transportationCollection = db.collection('transportation');
        const result = await transportationCollection.insertOne(transportationData);

        if (result.insertedId) {
            res.status(201).json({
                success: true,
                message: 'Transportation schedule created successfully',
                transportation: {
                    _id: result.insertedId,
                    ...transportationData
                }
            });
        } else {
            throw new Error('Failed to insert transportation schedule');
        }

    } catch (error) {
        console.error('Create transportation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create transportation schedule',
            error: error.message
        });
    }
});

// PUT - Update transportation schedule
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            name,
            time,
            location,
            googleMapsLink,
            parking,
            capacity,
            status,
            days,
            description
        } = req.body;

        // Validate ObjectId
        if (!ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid transportation schedule ID'
            });
        }

        // Validate required fields
        if (!name || !time || !location || !parking || !capacity) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: name, time, location, parking, capacity'
            });
        }

        // Validate capacity
        if (parseInt(capacity) < 1) {
            return res.status(400).json({
                success: false,
                message: 'Capacity must be at least 1'
            });
        }

        // Validate Google Maps link if provided
        if (googleMapsLink && !googleMapsLink.match(/^https?:\/\/.+/)) {
            return res.status(400).json({
                success: false,
                message: 'Google Maps link must be a valid URL'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        // Update transportation schedule
        const updateData = {
            name: name.trim(),
            time,
            location: location.trim(),
            googleMapsLink: googleMapsLink ? googleMapsLink.trim() : '',
            parking: parking.trim(),
            capacity: parseInt(capacity),
            status: status || 'Active',
            days: Array.isArray(days) ? days : [],
            description: description ? description.trim() : '',
            updatedAt: new Date()
        };

        const transportationCollection = db.collection('transportation');
        const result = await transportationCollection.updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transportation schedule not found'
            });
        }

        if (result.modifiedCount === 0) {
            return res.status(200).json({
                success: true,
                message: 'No changes were made to the transportation schedule'
            });
        }

        res.json({
            success: true,
            message: 'Transportation schedule updated successfully'
        });

    } catch (error) {
        console.error('Update transportation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update transportation schedule',
            error: error.message
        });
    }
});

// DELETE - Delete transportation schedule
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Validate ObjectId
        if (!ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid transportation schedule ID'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        const transportationCollection = db.collection('transportation');
        const result = await transportationCollection.deleteOne({
            _id: new ObjectId(id)
        });

        if (result.deletedCount === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transportation schedule not found'
            });
        }

        res.json({
            success: true,
            message: 'Transportation schedule deleted successfully'
        });

    } catch (error) {
        console.error('Delete transportation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete transportation schedule',
            error: error.message
        });
    }
});

// GET - Get transportation schedule by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Validate ObjectId
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid transportation schedule ID'
            });
        }

        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        const transportationCollection = db.collection('transportation');
        const transportation = await transportationCollection.findOne({
            _id: new mongoose.Types.ObjectId(id)
        });

        if (!transportation) {
            return res.status(404).json({
                success: false,
                message: 'Transportation schedule not found'
            });
        }

        res.json({
            success: true,
            transportation
        });

    } catch (error) {
        console.error('Get transportation by ID error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get transportation schedule',
            error: error.message
        });
    }
});

// GET - Get active transportation schedules only
router.get('/active/schedules', async (req, res) => {
    try {
        const db = req.app.locals.db;
        if (!db) {
            return res.status(500).json({
                success: false,
                message: 'Database connection not available'
            });
        }

        const transportationCollection = db.collection('transportation');
        const activeTransportation = await transportationCollection
            .find({ status: 'Active' })
            .sort({ time: 1 })
            .toArray();

        res.json({
            success: true,
            transportation: activeTransportation || [],
            count: activeTransportation.length
        });

    } catch (error) {
        console.error('Get active transportation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get active transportation schedules',
            error: error.message
        });
    }
});

module.exports = router;