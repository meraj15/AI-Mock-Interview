import React, { createContext, useContext, useState, useEffect } from 'react';

export type DateRangeOption = 'today' | '7d' | '30d' | '90d' | 'this_month' | 'last_month' | 'custom';

interface FilterContextType {
  dateRange: DateRangeOption;
  setDateRange: (range: DateRangeOption) => void;
  customStart: string;
  setCustomStart: (val: string) => void;
  customEnd: string;
  setCustomEnd: (val: string) => void;
  autoRefresh: number; // in seconds (0 = off)
  setAutoRefresh: (val: number) => void;
  refreshKey: number;
  triggerRefresh: () => void;
  lastRefreshedAt: Date;
}

const FilterContext = createContext<FilterContextType | undefined>(undefined);

export const FilterProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [dateRange, setDateRange] = useState<DateRangeOption>('30d');
  const [customStart, setCustomStart] = useState<string>('');
  const [customEnd, setCustomEnd] = useState<string>('');
  const [autoRefresh, setAutoRefresh] = useState<number>(0);
  const [refreshKey, setRefreshKey] = useState<number>(0);
  const [lastRefreshedAt, setLastRefreshedAt] = useState<Date>(new Date());

  const triggerRefresh = () => {
    setRefreshKey((prev) => prev + 1);
    setLastRefreshedAt(new Date());
  };

  useEffect(() => {
    if (autoRefresh <= 0) return;
    const interval = setInterval(() => {
      triggerRefresh();
    }, autoRefresh * 1000);
    return () => clearInterval(interval);
  }, [autoRefresh]);

  return (
    <FilterContext.Provider
      value={{
        dateRange,
        setDateRange,
        customStart,
        setCustomStart,
        customEnd,
        setCustomEnd,
        autoRefresh,
        setAutoRefresh,
        refreshKey,
        triggerRefresh,
        lastRefreshedAt,
      }}
    >
      {children}
    </FilterContext.Provider>
  );
};

export const useFilter = () => {
  const context = useContext(FilterContext);
  if (!context) {
    throw new Error('useFilter must be used within a FilterProvider');
  }
  return context;
};
