import React, { createContext, useState, useContext, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Price tables by period
export const PRICE_PERIODS = {
    'before_05_2025': {
        id: 'before_05_2025',
        name: 'Trước tháng 5/2025',
        shortName: 'Trước 5/2025',
        validFrom: null,
        validTo: '2025-04-30'
    },
    'from_05_2025': {
        id: 'from_05_2025',
        name: 'Hiện tại',
        shortName: 'Hiện tại',
        validFrom: '2025-05-01',
        validTo: null
    }
};

// Default prices for each period
export const DEFAULT_PRICE_TABLES = {
    'before_05_2025': {
        // Giá sinh hoạt bậc thang (trước 5/2025)
        tier1: 1893,
        tier2: 1956,
        tier3: 2271,
        tier4: 2860,
        tier5: 3197,
        tier6: 3302,
        // Giá theo nhóm
        production: 1896,      // Sản xuất
        business: 3007,        // Kinh doanh
        hcsn_hospital: 1977,   // HCSN - Bệnh viện, nhà trẻ, trường học
        hcsn_lighting: 2124,   // HCSN - Chiếu sáng công cộng
        // Thuế VAT
        vat: 0.08
    },
    'from_05_2025': {
        // Giá sinh hoạt bậc thang (từ 5/2025) - Cập nhật theo quy định mới
        tier1: 1893,
        tier2: 1956,
        tier3: 2271,
        tier4: 2860,
        tier5: 3197,
        tier6: 3302,
        // Giá theo nhóm (giữ nguyên hoặc cập nhật khi có thông tin mới)
        production: 1920,
        business: 3100,
        hcsn_hospital: 2000,
        hcsn_lighting: 2150,
        // Thuế VAT
        vat: 0.08
    }
};

const STORAGE_KEY = '@electricity_price_tables';
const SELECTED_PERIOD_KEY = '@selected_price_period';

const SettingsContext = createContext();

export const SettingsProvider = ({ children }) => {
    const [priceTables, setPriceTables] = useState(DEFAULT_PRICE_TABLES);
    const [selectedPeriod, setSelectedPeriod] = useState('from_05_2025');
    const [loading, setLoading] = useState(true);

    // Current active prices (shortcut)
    const prices = priceTables[selectedPeriod] || DEFAULT_PRICE_TABLES['from_05_2025'];

    useEffect(() => {
        loadSettings();
    }, []);

    const loadSettings = async () => {
        try {
            const [storedTables, storedPeriod] = await Promise.all([
                AsyncStorage.getItem(STORAGE_KEY),
                AsyncStorage.getItem(SELECTED_PERIOD_KEY)
            ]);

            if (storedTables) {
                const parsed = JSON.parse(storedTables);
                // Merge with defaults to ensure all keys exist
                const merged = { ...DEFAULT_PRICE_TABLES };
                Object.keys(parsed).forEach(period => {
                    merged[period] = { ...DEFAULT_PRICE_TABLES[period], ...parsed[period] };
                });
                setPriceTables(merged);
            }

            if (storedPeriod) {
                setSelectedPeriod(storedPeriod);
            }
        } catch (error) {
            console.error('Failed to load price settings:', error);
        } finally {
            setLoading(false);
        }
    };

    const savePriceTables = async (newTables) => {
        try {
            setPriceTables(newTables);
            await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(newTables));
        } catch (error) {
            console.error('Failed to save price tables:', error);
        }
    };

    const updatePriceForPeriod = async (periodId, newPrices) => {
        const updated = {
            ...priceTables,
            [periodId]: { ...priceTables[periodId], ...newPrices }
        };
        await savePriceTables(updated);
    };

    const selectPeriod = async (periodId) => {
        try {
            setSelectedPeriod(periodId);
            await AsyncStorage.setItem(SELECTED_PERIOD_KEY, periodId);
        } catch (error) {
            console.error('Failed to save selected period:', error);
        }
    };

    const resetToDefaults = async (periodId = null) => {
        try {
            if (periodId) {
                // Reset only specific period
                const updated = {
                    ...priceTables,
                    [periodId]: DEFAULT_PRICE_TABLES[periodId]
                };
                await savePriceTables(updated);
            } else {
                // Reset all periods
                setPriceTables(DEFAULT_PRICE_TABLES);
                await AsyncStorage.removeItem(STORAGE_KEY);
            }
        } catch (error) {
            console.error('Failed to reset prices:', error);
        }
    };

    // Auto-detect period based on year and month
    const suggestPeriod = (year, month) => {
        // month is 0-indexed (0 = January)
        if (year < 2025) return 'before_05_2025';
        if (year === 2025 && month < 4) return 'before_05_2025'; // Before May 2025
        return 'from_05_2025';
    };

    // Get prices for a specific period
    const getPricesForPeriod = (periodId) => {
        return priceTables[periodId] || DEFAULT_PRICE_TABLES[periodId] || prices;
    };

    return (
        <SettingsContext.Provider value={{
            prices,
            priceTables,
            selectedPeriod,
            loading,
            updatePriceForPeriod,
            selectPeriod,
            resetToDefaults,
            suggestPeriod,
            getPricesForPeriod,
            PRICE_PERIODS,
            DEFAULT_PRICE_TABLES
        }}>
            {children}
        </SettingsContext.Provider>
    );
};

export const useSettings = () => {
    const context = useContext(SettingsContext);
    if (!context) {
        throw new Error('useSettings must be used within a SettingsProvider');
    }
    return context;
};
