import React from 'react';
import { StyleSheet, View, Text, TextInput } from 'react-native';
import { Colors } from '../theme/colors';

const ProportionRow = ({ label, value, onValueChange }) => {
    return (
        <View style={styles.row}>
            <Text style={styles.label}>{label}</Text>
            <View style={styles.inputContainer}>
                <TextInput
                    style={styles.input}
                    keyboardType="decimal-pad"
                    value={String(Math.round(value * 100))}
                    onChangeText={(text) => {
                        const num = parseFloat(text);
                        if (!isNaN(num)) {
                            onValueChange(num / 100);
                        } else if (text === "") {
                            onValueChange(0);
                        }
                    }}
                    textAlign="right"
                />
                <Text style={styles.percentText}>%</Text>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 8,
    },
    label: {
        fontSize: 12,
        color: Colors.text,
    },
    inputContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.white,
        borderWidth: 1,
        borderColor: Colors.border,
        borderRadius: 6,
        paddingHorizontal: 8,
        width: 80,
        height: 32,
    },
    input: {
        flex: 1,
        fontSize: 12,
        padding: 0,
        color: Colors.text,
    },
    percentText: {
        fontSize: 12,
        color: Colors.textSecondary,
        marginLeft: 2,
    },
});

export default ProportionRow;
