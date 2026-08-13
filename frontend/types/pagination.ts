// Mirrors ApplicationController#pagination_meta — shared by every paginated
// resource (Products, Suppliers, ...), not specific to any one of them.
export interface PaginationMeta {
  page: number;
  per_page: number;
  total_pages: number;
  total_count: number;
}
