import {
  ORDER_STATUSES,
  ORDER_FILTER_OPTIONS,
  COLOR_OPTIONS,
  MATERIAL_OPTIONS,
  ODISHA_DISTRICTS,
} from '../src/utils/constants';

describe('Backend Centralized Constants Tests', () => {
  it('has exact order statuses', () => {
    expect(ORDER_STATUSES).toEqual([
      'Pending',
      'Approved',
      'Production',
      'Dispatched',
      'Delivered',
    ]);
  });

  it('has exact order filter options', () => {
    expect(ORDER_FILTER_OPTIONS).toEqual([
      'All',
      'Pending',
      'Approved',
      'Production',
      'Dispatched',
      'Delivered',
    ]);
  });

  it('has exact 10 color options', () => {
    expect(COLOR_OPTIONS).toEqual([
      'Black',
      'White',
      'Navy Blue',
      'Royal Blue',
      'Grey',
      'Maroon',
      'Red',
      'Sky',
      'Bottle Green',
      'Other',
    ]);
  });

  it('has exact 11 material options', () => {
    expect(MATERIAL_OPTIONS).toEqual([
      'Spun Matty',
      'PC Matty',
      'US Polo',
      'Techno Matty',
      'Drifit',
      'Dot knit',
      'Serena',
      'Red Tag',
      'Oversized',
      'Promotional',
      'Others',
    ]);
  });

  it('contains all 30 canonical Odisha districts', () => {
    expect(ODISHA_DISTRICTS.length).toBe(30);
    expect(new Set(ODISHA_DISTRICTS).size).toBe(30);
    expect(ODISHA_DISTRICTS).toContain('Cuttack');
    expect(ODISHA_DISTRICTS).toContain('Khordha');
    expect(ODISHA_DISTRICTS).toContain('Puri');
    expect(ODISHA_DISTRICTS).toContain('Sambalpur');
  });
});
